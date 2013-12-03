#define scriptSelection
if (argument0.highlighted == 1 && argument0.Selection == 0)
then if (global.to != 0 && global.to != global.from)
     then argument0.sprite_index = argument4;
     else argument0.sprite_index = argument1;
else if (argument0.Selection == 1)
then if ((mouse_check_button(mb_left) == 1 && global.leftSelect == 1) ||
            (mouse_check_button(mb_right)== 1 && global.rightSelect== 1))
        then argument0.sprite_index = argument3;
        else argument0.Selection = 0;
else argument0.sprite_index = argument2;

