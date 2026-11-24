package org.isetn;

import java.io.Serializable;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AbsenceId implements Serializable {
	private Long codMat;
	private Long nce;
	private LocalDate dateA;
}
