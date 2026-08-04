# Cloning repo
git clone https://github.com/telemt/telemt 
# Changing Directory to telemt
cd telemt
# Starting Release Build
cargo build --release

# Current release profile uses lto = "fat" for maximum optimization (see Cargo.toml).
# On low-RAM systems (~1 GB) you can override it to "thin".

# Move to /bin
mv ./target/release/telemt /bin
# Make executable
chmod +x /bin/telemt
# Lets go!
telemt config.toml
