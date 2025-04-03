package com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs;

public record LoginResponseDTO(
        String token,
        UsuarioResponseDTO usuario
) {
}
