if {[info exists ::env(OUTPUT_FILE)]} {
  set output_file $::env(OUTPUT_FILE)
} else {
  set output_file "$::env(REPORTS_DIR)/final_all_hi.webp"
}

if {[info exists ::env(IMAGE_SCALE)]} {
  set image_scale $::env(IMAGE_SCALE)
} else {
  set image_scale 4
}

read_db $::env(RESULTS_DIR)/6_final.odb

set height [[[ord::get_db_block] getBBox] getDY]
set height [ord::dbu_to_microns $height]
set resolution [expr {$height / (1000.0 * $image_scale)}]

set gui_script [format {
  gui::clear_highlights -1
  gui::clear_selections
  gui::fit

  gui::set_display_controls "*" visible false
  gui::set_display_controls "Layers/*" visible true
  gui::set_display_controls "Nets/*" visible true
  gui::set_display_controls "Instances/*" visible true
  gui::set_display_controls "Shape Types/*" visible true
  gui::set_display_controls "Misc/Instances/*" visible false
  gui::set_display_controls "Misc/Instances/Pins" visible true
  gui::set_display_controls "Misc/Instances/Blockages" visible true
  gui::set_display_controls "Misc/Scale bar" visible true
  gui::set_display_controls "Misc/Highlight selected" visible true
  gui::set_display_controls "Misc/Detailed view" visible true

  save_image -resolution %s %s
} $resolution [list $output_file]]

gui::show $gui_script false

exit
