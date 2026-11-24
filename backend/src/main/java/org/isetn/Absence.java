package org.isetn;

import java.time.LocalDate;
import javax.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@IdClass(AbsenceId.class)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Absence {
	@Id private Long codMat;
	@Id private Long nce;
	@Id private LocalDate dateA;
	private Integer nha;
}
