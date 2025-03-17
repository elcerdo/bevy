use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

pub const SHADER_PATH: &str = "shaders/morpheus/material/warped.wgsl";

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct WarpedMaterial {
    #[texture(0)]
    #[sampler(1)]
    pub pattern_texture: Option<Handle<Image>>,
    #[texture(2)]
    #[sampler(3)]
    pub warp_texture: Option<Handle<Image>>,
    #[uniform(4)]
    pub warp_amount: f32,
}

impl Material for WarpedMaterial {
    // fn vertex_shader() -> ShaderRef {
    //     SHADER_PATH.into()
    // }

    fn fragment_shader() -> ShaderRef {
        SHADER_PATH.into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

impl WarpedMaterial {
    pub fn new(pattern_texture: Handle<Image>, warp_texture: Handle<Image>) -> Self {
        Self {
            pattern_texture: Some(pattern_texture),
            warp_texture: Some(warp_texture),
            warp_amount: 1.0,
        }
    }
}
