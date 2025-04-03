package com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs;

import java.util.Date;

public record PostUsuarioDTO(
        String nomeCompleto,
        String cpf,
        String email,
        String senha,
        Date dataNascimento
) {
}
