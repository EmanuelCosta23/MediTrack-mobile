package com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs;

import java.util.Date;

public record EditUsuarioDTO(
        String usuarioId,
        String novoEmail,
        String novoNome,
        Date novaDataNascimento
) {
}
