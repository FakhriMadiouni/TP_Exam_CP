package org.isetn;

import javax.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Departement {
	@Id @GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long codDept;
	private String nomDept;
}
