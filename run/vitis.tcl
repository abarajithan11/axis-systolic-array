# Set paths and project names
set base_path "../.."
set project "sa_zcu104"
set ws_path "vitis"
set xsa_path "$project/design_1_wrapper.xsa"
set app_name "sa_app"
set sys_proj "sa_sys"

# Setup workspace
# setws $ws_path

# Create application project with Hello World template
app create -name $app_name -hw $xsa_path  -proc psu_cortexa53_0 -os standalone \
    -template "Hello World" -sysproj $sys_proj

# Overwrite helloworld.c with custom code from c/xilinx_example.c
file copy -force "$base_path/c/xilinx_example.c" "$ws_path/$app_name/src/helloworld.c"

# Add include directories to C build settings
app config -name $app_name -add include-path "$base_path/c/"
app config -name $app_name -add include-path "$base_path/run/work/data/"

# Build the project
app build -name $app_name