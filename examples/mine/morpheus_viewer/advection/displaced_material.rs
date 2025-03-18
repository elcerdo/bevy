use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

pub const SHADER_PATH: &str = "shaders/morpheus/material/displaced.wgsl";

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct DisplacedMaterial {
    #[texture(0)]
    pub pattern_texture: Handle<Image>,
}

impl Material for DisplacedMaterial {
    fn vertex_shader() -> ShaderRef {
        SHADER_PATH.into()
    }

    fn fragment_shader() -> ShaderRef {
        SHADER_PATH.into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

impl DisplacedMaterial {
    pub fn new(pattern_texture: Handle<Image>) -> Self {
        Self { pattern_texture }
    }
}
