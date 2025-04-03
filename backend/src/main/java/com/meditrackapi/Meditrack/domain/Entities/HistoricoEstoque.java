package com.meditrackapi.Meditrack.domain.Entities;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Table(name = "historico_estoque")
@Entity
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HistoricoEstoque {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @ManyToOne
    @JoinColumn(name = "posto_id")
    Posto posto;
    @OneToOne
    @JoinColumn(name = "funcionario_id")
    Usuario funcionario;
    @JsonFormat(pattern = "dd/MM/yyyy HH:mm:ss")
    @CreationTimestamp
    private LocalDateTime dataUpload;

    public HistoricoEstoque(Posto posto, Usuario funcionario){
        this.posto = posto;
        this.funcionario = funcionario;
    }
}
