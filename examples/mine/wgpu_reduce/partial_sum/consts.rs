use bevy::render::render_resource::TextureFormat;

// pub const TEXTURE_FORMAT: TextureFormat = TextureFormat::Rg32Uint; FIXME
pub const TEXTURE_FORMAT: TextureFormat = TextureFormat::Rgba32Uint;
pub const TEXTURE_SIZE: (u32, u32) = (256, 64);
pub const WORKGROUP_SIZE: (u32, u32) = (8, 8);
