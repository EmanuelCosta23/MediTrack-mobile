package com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response;

import com.opencsv.bean.CsvBindByName;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class UpdateEstoqueCsvReprensentation {
    @CsvBindByName(column = "codigo")
    private int _codigo;
    @CsvBindByName(column = "quantidade")
    private int _quantidade;
}
