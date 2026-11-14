extends SceneTree
## Real complete cache/ShaderMaterial binding, headless: NOT a GPU/pixel test.
const Battle=preload("res://scripts/field/battle.gd")
const Store=preload("res://scripts/field/save.gd")
const Actor=preload("res://scripts/field/experimental/controlled_author_actor.gd")
const Binding=preload("res://scripts/field/experimental/author_unit_binding.gd")
const Harness=preload("res://scripts/review/author_dynamic_review.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var cache=OS.get_environment("LUANSHI_AUTHOR_ORACLE_CACHE")
	if cache.is_empty():push_error("EXPLICIT_AUTHOR_CACHE_REQUIRED");quit(2);return
	var actor=Actor.new();root.add_child(actor)
	assert(actor.configure_author_oracle(cache)==OK)
	assert(actor.get_child_count()==43 and actor.mats.size()>0)
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/author_thrust_peak.json"))
	var binding=Binding.new();binding.enabled=true
	assert(Harness.validated_peak(actor.metadata,{"source_sha256":source.source_sha256,"peak_phase":source.peak_phase})<0.0)
	binding.thrust_peak=Harness.validated_peak(actor.metadata,source)
	assert(is_equal_approx(binding.thrust_peak,19.0/36.0))
	var a=Battle.new();var twin=Battle.new();a.setup(20);twin.setup(20);a.start();twin.start()
	var counts={"walk":0,"fallback":0,"thrust":0}
	for tick in 240:
		for b in [a,twin]:
			b.input_state(Vector2.RIGHT*0.6 if tick%100<60 else Vector2.ZERO,Vector2.RIGHT)
			if tick%70==0:b.press_action(0)
			b.step()
		var before=var_to_bytes(Store.snapshot(a))
		var sample=binding.update_once(a,actor)
		assert(var_to_bytes(Store.snapshot(a))==before and var_to_bytes(Store.snapshot(twin))==before)
		if sample.supported:
			assert(sample.clip in ["walk","thrust"] and actor.visible and binding.hidden_unit_id==a.hero.id)
			counts[sample.clip]+=1
			for mat in actor.mats:
				assert(is_equal_approx(float(mat.get_shader_parameter("sample_frame")),sample.phase*32.0 if sample.clip=="walk" else 33.0+sample.phase*36.0))
		else:
			counts.fallback+=1
			assert(not actor.visible and binding.hidden_unit_id==-1)
		assert(binding.update_once(a,actor)==sample)
	assert(counts.walk>0 and counts.thrust>0 and counts.fallback>0)
	binding.disable(actor);assert(not actor.visible and binding.hidden_unit_id==-1)
	print("AUTHOR_REAL_CACHE_CPU_PASS ",JSON.stringify({"counts":counts,"receipt":actor.receipt(),"unbound_input_hash_rejected":true,"exact_job_output_bound":true,"GPU":"NOT_RUN","full_controller":"NOT_RUN"}))
	actor.queue_free();quit()
