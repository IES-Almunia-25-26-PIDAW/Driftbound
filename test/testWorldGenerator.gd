extends GutTest

var world_generator

func before_each():

	world_generator = preload("res://World/WorldGenerator.gd").new()


func test_noise_is_created():

	world_generator.setup_noise()

	assert_not_null(world_generator.noise)


func test_noise_returns_valid_range():

	world_generator.setup_noise()

	var value = world_generator.noise.get_noise_2d(10, 10)

	assert_true(value >= -1.0)
	assert_true(value <= 1.0)


func test_map_dimensions():

	world_generator.map_width = 50
	world_generator.map_height = 60

	assert_eq(world_generator.map_width, 50)
	assert_eq(world_generator.map_height, 60)
	
func test_generate_world():
	world_generator.map_width = 10
	world_generator.map_height = 10
	
	world_generator.generate_world()
	
	for i in range(world_generator.map_width):
		for j in range(world_generator.map_height):
			assert_true(world_generator.worldMap[[i,j]] >= -1.0)
			assert_true(world_generator.worldMap[[i,j]] <= 1.0)
		
func test_spawn_point():
	world_generator.set_spawn_point()
	assert_true(world_generator.spawn_point <= 198)
	assert_true(world_generator.spawn_point >= 2)
	assert_true(world_generator.spawn_point%2 == 0)
