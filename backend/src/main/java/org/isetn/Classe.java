package org.isetn;

import javax.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Classe {
	@Id @GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long codClass;
	private String nomClass;
	private Integer nbrEtud;
	@ManyToOne
	@JoinColumn(name = "cod_dept")
	private Departement departement;
}
