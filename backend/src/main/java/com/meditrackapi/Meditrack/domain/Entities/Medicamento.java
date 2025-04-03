package com.meditrackapi.Meditrack.domain.Entities;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigInteger;
import java.util.Date;
import java.util.Set;

@Table(name = "medicamento")
@Entity
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Medicamento {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    private int codigo;
    private String lote;
    private String produto;
    private String tipo;
    private Date vencimento;
    private boolean necessitaReceita;
    @ManyToMany
    @JoinTable(name = "medicamento_posto",
            joinColumns = @JoinColumn(name = "medicamento_id"),
            inverseJoinColumns = @JoinColumn(name = "posto_id"))
    private Set<Posto> postos;
}
