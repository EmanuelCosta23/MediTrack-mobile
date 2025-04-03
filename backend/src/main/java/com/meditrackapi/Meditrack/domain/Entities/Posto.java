package com.meditrackapi.Meditrack.domain.Entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.Set;

@Table(name = "posto")
@Entity
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class Posto {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    private String nome;
    private String bairro;
    private String rua;
    private String numero;
    private String linhasOnibus;
    private String telefone;
    @Column(precision = 9, scale = 6, nullable = false)
    private BigDecimal latitude;
    @Column(precision = 9, scale = 6, nullable = false)
    private BigDecimal longitude;
    @ManyToMany
    @JoinTable(name = "medicamento_posto",
            joinColumns = @JoinColumn(name = "medicamento_id"),
            inverseJoinColumns = @JoinColumn(name = "posto_id"))
    private Set<Posto> postos;
}
