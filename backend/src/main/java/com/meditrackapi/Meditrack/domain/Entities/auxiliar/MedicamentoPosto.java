package com.meditrackapi.Meditrack.domain.Entities.auxiliar;

import com.meditrackapi.Meditrack.domain.Entities.Medicamento;
import com.meditrackapi.Meditrack.domain.Entities.Posto;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "medicamento_posto")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MedicamentoPosto {

    @EmbeddedId
    private MedicamentoPostoId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("medicamentoId")
    @JoinColumn(name = "medicamento_id")
    private Medicamento medicamento;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("postoId")
    @JoinColumn(name = "posto_id")
    private Posto posto;

    @Column(name = "quantidade_estoque", nullable = false)
    private int quantidadeEstoque;

    public MedicamentoPosto(Medicamento medicamento, Posto posto, int quantidadeEstoque) {
        this.medicamento = medicamento;
        this.posto = posto;
        this.quantidadeEstoque = quantidadeEstoque;
        this.id = new MedicamentoPostoId(medicamento.getId(), posto.getId());
    }
}
