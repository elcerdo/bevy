use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef, TextureViewDimension};

pub const SHADER_PATH: &str = "shaders/wgpu_reduce/debug.wgsl";

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct DebugMaterial {
    #[storage_texture(0, image_format=Rg32Uint)] // FIXME use TEXTURE_FORMAT
    pub data_texture: Handle<Image>,
    // #[sampler(1)]
    // #[texture(2)]
    // #[sampler(3)]
    // pub warp_texture: Option<Handle<Image>>,
    // #[uniform(4)]
    // pub warp_amount: f32,
}

impl Material for DebugMaterial {
    fn fragment_shader() -> ShaderRef {
        SHADER_PATH.into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}
