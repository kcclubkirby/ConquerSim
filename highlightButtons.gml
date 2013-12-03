#define highlightButtons
if (mouse_x > argument0.x
    &&mouse_x < (argument0.x + sprite_get_bbox_right(argument1))
    &&mouse_y > argument0.y
    &&mouse_y < (argument0.y + sprite_get_bbox_bottom(argument1)))
then{
        if argument0.highlighted = 0
        then{
                argument0.highlighted = 1;
                argument0.sprite_index = argument1;
            }
    }
else{
        if argument0.highlighted = 1
        then{
                argument0.highlighted = 0;
                argument0.sprite_index = argument2;
            }
    }
    
if (argument0.highlighted = 1 && mouse_check_button_pressed(mb_left))
then argument0.clicked = 1;
else argument0.clicked = 0;

if argument0.highlighted == 1
then argument0.sprite_index = argument1;

if argument0.highlighted == 0
then argument0.sprite_index = argument2;

