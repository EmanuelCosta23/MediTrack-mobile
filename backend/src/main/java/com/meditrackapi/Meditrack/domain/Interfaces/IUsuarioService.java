package com.meditrackapi.Meditrack.domain.Interfaces;

import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.*;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;

import java.util.List;

public interface IUsuarioService {
    UsuarioResponseDTO cadastrarUsuario(PostUsuarioDTO novoUsuario);
    boolean confirmarEmail(String userId, String authCode);
    public UsuarioResponseDTO editarUsuario(EditUsuarioDTO usuarioInfos);
    LoginResponseDTO login(UserLoginDTO userLogin);
    UsuarioResponseDTO getUsuarioByAuthToken();
    List<Usuario> listarTodosUsuarios();
    void ChangePassword(String newPassword);
}
