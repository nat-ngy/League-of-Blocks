extends Character
#maybe add class_name if we want class to be global but at the moment i don't see why

var countdown: int = 50

func _init():
	cooldown = 0

func attack(n:int):
	countdown -= n
	if countdown == 0:
		win.emit()
	super(n)

func attack_response(n:int):
	super(n)

func active():
	super()
