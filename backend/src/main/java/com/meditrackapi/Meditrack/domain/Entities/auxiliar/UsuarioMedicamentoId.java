package com.meditrackapi.Meditrack.domain.Entities.auxiliar;

import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Embeddable
public class UsuarioMedicamentoId {

    private String usuarioId;
    private String medicamentoId;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UsuarioMedicamentoId that = (UsuarioMedicamentoId) o;
        return Objects.equals(usuarioId, that.usuarioId) && Objects.equals(medicamentoId, that.medicamentoId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(medicamentoId, medicamentoId);
    }
}
