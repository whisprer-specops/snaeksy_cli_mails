use std::env;
use std::fs;
use std::path::Path;

fn main() {
    // Get output directory from cargo
    let out_dir = env::var("OUT_DIR").unwrap();
    
    // Get build profile (debug or release)
    let profile = env::var("PROFILE").unwrap();
    
    // Print build information
    println!("cargo:warning=Building SecureCrypt in {} mode", profile);
    
    // Create directories structure if needed
    fs::create_dir_all(Path::new(&out_dir).join("config")).unwrap_or_else(|_| {
        println!("cargo:warning=Failed to create config directory");
    });
    
    // Add any additional build steps here
    
    // Rerun the build script if these files change
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=Cargo.toml");
}