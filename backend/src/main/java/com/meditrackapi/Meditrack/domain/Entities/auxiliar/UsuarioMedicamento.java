package com.meditrackapi.Meditrack.domain.Entities.auxiliar;

import com.meditrackapi.Meditrack.domain.Entities.Medicamento;
import com.meditrackapi.Meditrack.domain.Entities.Posto;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "usuario_medicamento")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UsuarioMedicamento {
    @EmbeddedId
    private UsuarioMedicamentoId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("usuarioId")
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("medicamentoId")
    @JoinColumn(name = "medicamento_id")
    private Medicamento medicamento;

    public UsuarioMedicamento(Usuario usuario, Medicamento medicamento) {
        this.medicamento = medicamento;
        this.usuario = usuario;
        this.id = new UsuarioMedicamentoId(usuario.getId(), medicamento.getId());
    }
}
