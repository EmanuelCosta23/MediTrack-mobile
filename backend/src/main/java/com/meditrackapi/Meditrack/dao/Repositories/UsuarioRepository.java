package com.meditrackapi.Meditrack.dao.Repositories;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import jakarta.annotation.Nonnull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, String> {

    @Nonnull
    Optional<Usuario> findById(@Nonnull String id);
    UserDetails findByEmail(String email);
    Usuario findByEmailOrCpf(String email, String cpf);
}
