use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

pub const SHADER_PATH: &str = "shaders/wgpu_reduce/debug.wgsl";

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct DebugMaterial {
    // FIXME does not work when TEXTURE_FORMAT is Rg32Uint
    #[texture(0, visibility(all), sample_type = "u_int")]
    pub data_texture: Handle<Image>,
}

impl Material for DebugMaterial {
    fn fragment_shader() -> ShaderRef {
        SHADER_PATH.into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}
