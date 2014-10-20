function smith_walterman_alignment(seq_1, seq_2){

  match_score = 1;
  miss_match_score = -6;
  deletion_score = -4;
  insertion_score = -4;

  overall_max_value = 0;
  max_position = [0,0,'S'];

  similarity_Score_matrix = [[]];
  directional_matrix = [[]];

  for (j = 0; j < seq_2.length; j++) {
    similarity_Score_matrix[0].push(0);
    directional_matrix[0].push([0, j, 'D']);
  }

  directional_matrix[0][0] = [0, 0, 'S'];

  for (i = 1; i < (seq_1.length + 1); i++) {
    similarity_Score_matrix.push([]);
    similarity_Score_matrix[i].push(0);
    directional_matrix.push([]);
    directional_matrix[i].push([i, 0, 'I']);

    for (j = 1; j < (seq_2.length + 1); j++) {

      if (directional_matrix[i-1][j-1][2] == 'M' || directional_matrix[i-1][j-1][2] == 'S'){
        if (seq_1[i-1] == seq_2[j-1]){
          match = similarity_Score_matrix[i-1][j-1] + match_score;
        } else {
          match = similarity_Score_matrix[i-1][j-1] + miss_match_score;
        }
      } else if (directional_matrix[i-1][j-1][2] == 'D'){
        if (seq_1[i-1] == seq_2[j-1]){
          match = similarity_Score_matrix[i-1][j-1] -5;
        } else {
          match = -100;
        }
      } else if (directional_matrix[i-1][j-1][2] == 'I'){
        if (seq_1[i-1] == seq_2[j-1]){
          match = similarity_Score_matrix[i-1][j-1] -5;
        } else {
          match = -100;
        }
      } else {
        match = -100;
      }

      deletion = similarity_Score_matrix[i][j-1] + deletion_score;
      insertion = similarity_Score_matrix[i-1][j] + insertion_score;

      max_value = match;
      position = [i-1,j-1,'M'];

      if (deletion > max_value){
        max_value = deletion;
        position = [i,j-1,'I'];
      }
      if (insertion > max_value){
        max_value = insertion;
        position = [i-1,j,'D'];
      }

      overall_max_value = max_value;
      max_position = [i,j];

      similarity_Score_matrix[i].push(max_value);
      directional_matrix[i].push(position);
    }
  }

  seq_1_aligned = "";
  seq_2_aligned = "";

  current_position = max_position;

  while (true) {
    direction = directional_matrix[current_position[0]][current_position[1]];


    if (direction[2] == 'M'){
      seq_1_aligned = seq_1[current_position[0] -1] + seq_1_aligned;
      seq_2_aligned = seq_2[current_position[1] -1] + seq_2_aligned;
    } else if (direction[2] == 'I'){
      seq_1_aligned = '-' + seq_1_aligned;
      seq_2_aligned = seq_2[current_position[1] -1] + seq_2_aligned;
    } else if (direction[2] == 'D'){
      seq_1_aligned = seq_1[current_position[0] -1] + seq_1_aligned;
      seq_2_aligned = '-' + seq_2_aligned;
    } else {
      break;
    }
    current_position = [direction[0] ,direction[1]];
  }
  return [seq_1_aligned, seq_2_aligned]
}




