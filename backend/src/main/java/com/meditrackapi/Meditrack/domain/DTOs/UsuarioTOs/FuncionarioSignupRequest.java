package com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs;

import java.util.Date;

public record FuncionarioSignupRequest (
        String nomeCompleto,
        String cpf,
        String email,
        Date dataNascimento,
        String postoId
){}
