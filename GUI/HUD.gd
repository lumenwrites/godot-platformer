extends CanvasLayer

var score = 0

func increment_score():
	score +=1
	$Control/Label.text = str(score)
