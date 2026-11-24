package org.isetn;

import java.time.LocalDate;
import javax.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Etudiant {
	@Id @GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long nce;
	private String nom;
	private String prenom;
	private LocalDate dateNais;
	private String lieuNais;
	@ManyToOne
	@JoinColumn(name = "cod_class")
	private Classe classe;
}
