package com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs;


public record UsuarioResponseDTO(
        String id,
        String nomeCompleto,
        String email,
        String cpf,
        String fotoPerfil,
        String tipo
) {
}
