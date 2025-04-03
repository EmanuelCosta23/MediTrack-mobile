package com.meditrackapi.Meditrack.domain.Interfaces;

import com.meditrackapi.Meditrack.domain.Entities.Usuario;

public interface IAuthenticationService {
    String createToken(Usuario usuario);
    String validateToken(String token);
}
