package com.meditrackapi.Meditrack.domain.Interfaces;

import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.FuncionarioSignupRequest;
import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.UsuarioResponseDTO;

public interface IAdminService {
    UsuarioResponseDTO cadastrarFuncionario(FuncionarioSignupRequest novoUsuario);
}
