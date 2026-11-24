package org.isetn;

import javax.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Matiere {
	@Id @GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long codMat;
	private String intMat;
	private String description;
}
