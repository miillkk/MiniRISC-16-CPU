## The 72-byte frame and head position are held in the 100 MHz domain before
## frame_toggle changes. The pixel domain synchronizes that toggle through two
## registers and captures the bus only after the synchronized change arrives.
## These source-to-destination paths are multi-cycle CDC transfers, not direct
## single-cycle paths. Keep all pixel-domain synchronizer stages timed.
set_false_path -from [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/held_frame_reg*}] -to [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/pixel_frame_reg*}]
set_false_path -from [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/held_head_reg*}] -to [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/pixel_head_reg*}]
set_false_path -from [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/frame_toggle_reg*}] -to [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/toggle_meta_reg*}]

## These two single-bit controls also enter dedicated first-stage synchronizers.
set_false_path -to [get_cells -hier -filter {NAME =~ *u_hdmi_video_subsystem/load_meta_reg* || NAME =~ *u_hdmi_video_subsystem/test_meta_reg*}]
