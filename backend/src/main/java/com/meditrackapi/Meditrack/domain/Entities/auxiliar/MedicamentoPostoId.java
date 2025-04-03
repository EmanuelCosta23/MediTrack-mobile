package com.meditrackapi.Meditrack.domain.Entities.auxiliar;

import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.util.Objects;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Embeddable
public class MedicamentoPostoId implements Serializable {

    private String medicamentoId;
    private String postoId;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        MedicamentoPostoId that = (MedicamentoPostoId) o;
        return Objects.equals(medicamentoId, that.medicamentoId) && Objects.equals(postoId, that.postoId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(medicamentoId, postoId);
    }
}
