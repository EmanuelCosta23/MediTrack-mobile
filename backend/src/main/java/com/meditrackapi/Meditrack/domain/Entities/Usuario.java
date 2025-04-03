package com.meditrackapi.Meditrack.domain.Entities;

import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.PostUsuarioDTO;
import com.meditrackapi.Meditrack.domain.Enums.Role;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.*;

@Table(name = "usuario")
@Entity
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class Usuario implements UserDetails {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    private String nomeCompleto;
    private String cpf;
    private String email;
    private String senha;
    private String fotoPerfil;
    private Date dataNascimento;
    @CreationTimestamp
    private Date criadoEm;
    @Enumerated(EnumType.STRING)
    private Role tipo = Role.ROLE_USUARIO;
    @OneToOne
    @JoinColumn(name = "posto_id")
    private Posto posto;
    private Boolean isVerificado = false;
    private String codigoVerificacao;

    public Usuario(PostUsuarioDTO novoUsuario, String encryptedPassword){
        this.nomeCompleto = novoUsuario.nomeCompleto();
        this.cpf = novoUsuario.cpf();
        this.email = novoUsuario.email();
        this.senha = encryptedPassword;
        this.fotoPerfil = "dev-teste";
        this.dataNascimento = novoUsuario.dataNascimento();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority(tipo.name()));
    }

    @Override
    public String getPassword() {
        return senha;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
