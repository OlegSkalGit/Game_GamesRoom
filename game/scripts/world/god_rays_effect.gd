class_name GodRaysEffect
extends CompositorEffect

var sun_uv: Vector2 = Vector2(0.5, 0.3)
var ray_strength: float = 0.0
var ray_color: Color = Color(1.0, 0.88, 0.66, 1.0)
var density: float = 0.90
var decay: float = 0.942
var weight: float = 0.062

var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _sampler: RID
var _scratch_tex: RID
var _scratch_size: Vector2i = Vector2i.ZERO


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	needs_motion_vectors = false
	needs_normal_roughness = false
	if RenderingServer.get_rendering_device() != null:
		RenderingServer.call_on_render_thread(_initialize_compute)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rd != null:
		if _scratch_tex.is_valid():
			_rd.free_rid(_scratch_tex)
			_scratch_tex = RID()
		if _sampler.is_valid():
			_rd.free_rid(_sampler)
			_sampler = RID()
		if _pipeline.is_valid():
			_rd.free_rid(_pipeline)
			_pipeline = RID()
		if _shader.is_valid():
			_rd.free_rid(_shader)
			_shader = RID()


func _initialize_compute() -> void:
	_rd = RenderingServer.get_rendering_device()
	if _rd == null:
		return
	var shader_file := load("res://shaders/god_rays.glsl") as RDShaderFile
	if shader_file == null:
		return
	var spirv := shader_file.get_spirv()
	if spirv == null or spirv.compile_error_compute != "":
		push_warning("GodRays compute compile error: " + (spirv.compile_error_compute if spirv else "null"))
		return
	_shader = _rd.shader_create_from_spirv(spirv)
	if _shader.is_valid():
		_pipeline = _rd.compute_pipeline_create(_shader)
	var ss := RDSamplerState.new()
	ss.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	ss.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	ss.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	ss.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	_sampler = _rd.sampler_create(ss)


func _ensure_scratch(sz: Vector2i) -> bool:
	if _scratch_tex.is_valid() and _scratch_size == sz:
		return true
	if _scratch_tex.is_valid():
		_rd.free_rid(_scratch_tex)
		_scratch_tex = RID()
	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	tf.width = sz.x
	tf.height = sz.y
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	_scratch_tex = _rd.texture_create(tf, RDTextureView.new())
	_scratch_size = sz
	return _scratch_tex.is_valid()


func _make_uniform_set(src_tex: RID, dst_img: RID, depth_tex: RID) -> RID:
	var u_src := RDUniform.new()
	u_src.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u_src.binding = 0
	u_src.add_id(_sampler)
	u_src.add_id(src_tex)

	var u_dst := RDUniform.new()
	u_dst.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_dst.binding = 1
	u_dst.add_id(dst_img)

	var u_dep := RDUniform.new()
	u_dep.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u_dep.binding = 2
	u_dep.add_id(_sampler)
	u_dep.add_id(depth_tex)

	return UniformSetCacheRD.get_cache(_shader, 0, [u_src, u_dst, u_dep])


func _render_callback(p_effect_callback_type: int, p_render_data: RenderData) -> void:
	if _rd == null or not _pipeline.is_valid() or not _sampler.is_valid():
		return
	if ray_strength <= 0.002 or p_effect_callback_type != EFFECT_CALLBACK_TYPE_POST_TRANSPARENT:
		return
	var buffers := p_render_data.get_render_scene_buffers()
	if not (buffers is RenderSceneBuffersRD):
		return
	var rd_buffers := buffers as RenderSceneBuffersRD
	var sz := rd_buffers.get_internal_size()
	if sz.x <= 8 or sz.y <= 8 or not _ensure_scratch(sz):
		return

	var x_groups := (sz.x + 7) / 8
	var y_groups := (sz.y + 7) / 8
	var view_count := rd_buffers.get_view_count()

	for view: int in range(view_count):
		var color_tex := rd_buffers.get_color_layer(view)
		var depth_tex := rd_buffers.get_depth_layer(view)
		if not color_tex.is_valid() or not depth_tex.is_valid():
			continue

		var gather_set := _make_uniform_set(color_tex, _scratch_tex, depth_tex)
		var blend_set := _make_uniform_set(_scratch_tex, color_tex, depth_tex)
		if not gather_set.is_valid() or not blend_set.is_valid():
			continue

		var pc_gather := PackedFloat32Array([
			float(sz.x), float(sz.y), sun_uv.x, sun_uv.y,
			ray_color.r, ray_color.g, ray_color.b, ray_strength,
			density, decay, weight, 0.0
		]).to_byte_array()
		var cl := _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(cl, _pipeline)
		_rd.compute_list_bind_uniform_set(cl, gather_set, 0)
		_rd.compute_list_set_push_constant(cl, pc_gather, pc_gather.size())
		_rd.compute_list_dispatch(cl, x_groups, y_groups, 1)
		_rd.compute_list_end()

		var pc_blend := PackedFloat32Array([
			float(sz.x), float(sz.y), sun_uv.x, sun_uv.y,
			ray_color.r, ray_color.g, ray_color.b, ray_strength,
			density, decay, weight, 1.0
		]).to_byte_array()
		cl = _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(cl, _pipeline)
		_rd.compute_list_bind_uniform_set(cl, blend_set, 0)
		_rd.compute_list_set_push_constant(cl, pc_blend, pc_blend.size())
		_rd.compute_list_dispatch(cl, x_groups, y_groups, 1)
		_rd.compute_list_end()
