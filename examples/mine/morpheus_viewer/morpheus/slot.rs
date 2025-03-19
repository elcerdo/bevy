use bevy::asset::weak_handle;
use bevy::render::render_resource::ShaderRef;

use bevy::prelude::*;

pub trait Slot: TypePath + Clone + Sync + Send {
    const RAY_HANDLE: Handle<Shader>;
    fn raymarching_shader() -> ShaderRef {
        Self::RAY_HANDLE.into()
    }
}

#[derive(Clone, TypePath)]
pub struct SlotN<const N: usize>;

impl<const N: usize> Slot for SlotN<N> {
    const RAY_HANDLE: Handle<Shader> = match N {
        0 => weak_handle!("7987c9b7-1598-0000-0000-023a354b7cac"),
        1 => weak_handle!("7987c9b7-1598-0000-0001-023a354b7cac"),
        2 => weak_handle!("7987c9b7-1598-0000-0002-023a354b7cac"),
        3 => weak_handle!("7987c9b7-1598-0000-0003-023a354b7cac"),
        4 => weak_handle!("7987c9b7-1598-0000-0004-023a354b7cac"),
        5 => weak_handle!("7987c9b7-1598-0000-0005-023a354b7cac"),
        6 => weak_handle!("7987c9b7-1598-0000-0006-023a354b7cac"),
        7 => weak_handle!("7987c9b7-1598-0000-0007-023a354b7cac"),
        _ => unreachable!(),
    };
}

pub type Slot0 = SlotN<0>;
pub type Slot1 = SlotN<1>;
pub type Slot2 = SlotN<2>;
pub type Slot3 = SlotN<3>;
pub type Slot4 = SlotN<4>;
pub type Slot5 = SlotN<5>;
pub type Slot6 = SlotN<6>;
pub type Slot7 = SlotN<7>;
