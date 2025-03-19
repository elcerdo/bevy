use crate::slot::Slot;

use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

use std::marker::PhantomData;

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct MorpheusRaymarchingMaterial<S: Slot> {
    #[texture(0)]
    #[sampler(1)]
    pub matcap_texture: Option<Handle<Image>>,
    #[uniform(2)]
    pub bbox_center: Vec3,
    #[uniform(3)]
    pub num_steps: u32,
    #[uniform(4)]
    pub step_bias: f32,
    phantom: PhantomData<S>,
}

impl<S: Slot> Material for MorpheusRaymarchingMaterial<S> {
    fn vertex_shader() -> ShaderRef {
        S::raymarching_shader()
    }

    fn fragment_shader() -> ShaderRef {
        S::raymarching_shader()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

impl<S: Slot> MorpheusRaymarchingMaterial<S> {
    pub fn new(matcap_texture: Handle<Image>, step_bias: f32) -> Self {
        Self {
            matcap_texture: Some(matcap_texture),
            bbox_center: Vec3::ZERO,
            num_steps: 64,
            step_bias,
            phantom: PhantomData,
        }
    }
}
