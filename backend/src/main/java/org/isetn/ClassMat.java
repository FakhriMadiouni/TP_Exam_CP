package org.isetn;

import javax.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@IdClass(ClassMatId.class)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ClassMat {
	@Id private Long codMat;
	@Id private Long codClass;
	private Double coef;
	private Integer chsm;
}
