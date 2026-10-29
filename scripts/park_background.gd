extends Node2D
var menu_mode = false
var camera: Camera2D
var reference = Vector2.ZERO
var image = preload("res://assets/park.webp")
func _process(_dt): queue_redraw()
func _draw():
	var screen = get_viewport_rect().size
	if menu_mode:
		var scale = maxf(screen.x/image.get_width(),screen.y/image.get_height())
		var size = image.get_size()*scale
		draw_texture_rect(image,Rect2((screen-size)/2,size),false)
		return
	var delta = camera.position-reference if is_instance_valid(camera) else Vector2.ZERO
	var h = screen.y*1.05
	var w = h*image.get_width()/image.get_height()
	var shift = fposmod(delta.x*0.14*screen.x/1280,2*w)
	var top = maxf(-h*0.25,screen.y*-0.03-delta.y*0.12*screen.y/720)
	draw_rect(Rect2(Vector2.ZERO,screen),Color("36a7ef"))
	for i in range(int(floor(shift/w)),int(ceil((screen.x+shift)/w))):
		var x = i*w-shift
		var mirrored = i%2!=0
		draw_set_transform(Vector2(x+w if mirrored else x,0),0,Vector2(-1 if mirrored else 1,1))
		draw_texture_rect(image,Rect2(0,top,w+0.5,h),false)
		if top>0: draw_texture_rect_region(image,Rect2(0,0,w+0.5,top+1),Rect2(0,0,image.get_width(),1))
		if top+h<screen.y: draw_texture_rect_region(image,Rect2(0,top+h-1,w+0.5,screen.y-top-h+1),Rect2(0,image.get_height()-1,image.get_width(),1))
	draw_set_transform(Vector2.ZERO)
