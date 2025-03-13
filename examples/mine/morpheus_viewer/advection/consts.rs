use bevy::render::render_resource::TextureFormat;

pub const SHADER_PATH: &str = "shaders/morpheus/advection.wgsl";
pub const TEXTURE_FORMAT: TextureFormat = TextureFormat::Rgba32Float;
pub const TEXTURE_SIZE: (u32, u32) = (1024, 1024);
pub const WORKGROUP_SIZE: u32 = 8;
