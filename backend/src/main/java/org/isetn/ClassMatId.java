package org.isetn;

import java.io.Serializable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ClassMatId implements Serializable {
	private Long codMat;
	private Long codClass;
}
