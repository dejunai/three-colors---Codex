extends RefCounted

var cards: Array = []
var index = 0
var display: Callable
var completed: Callable

func start(sequence:Array,show_card:Callable,after:Callable) -> void:
	cards=sequence.duplicate(true)
	index=0
	display=show_card
	completed=after
	if cards.is_empty():
		var callback=completed
		completed=Callable()
		callback.call()
	else: display.call(cards[index],index)

func next() -> void:
	if not completed.is_valid(): return
	index+=1
	if index < cards.size(): display.call(cards[index],index)
	else:
		var callback=completed
		completed=Callable()
		callback.call()
