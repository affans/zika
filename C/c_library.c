void agestructute() // for Colombia
{
  ProbBirthAge[1]  = 9.12e-2; // 0–4 years
  ProbBirthAge[2]  = 9.05e-2; // 5–9 years
  ProbBirthAge[3]  = 9.18e-2; // 10–14
  ProbBirthAge[4]  = 9.31e-2; // 15–19
  ProbBirthAge[5]  = 8.96e-2; // 20–24
  ProbBirthAge[6]  = 8.10e-2; // 25–29
  ProbBirthAge[7]  = 7.27e-2; // 30–34
  ProbBirthAge[8]  = 6.52e-2; // 35–39
  ProbBirthAge[9]  = 6.11e-2; // 40–44
  ProbBirthAge[10] = 6.07e-2; // 45–49
  ProbBirthAge[11] = 5.40e-2; // 50–54
  ProbBirthAge[12] = 4.35e-2; // 55–59
  ProbBirthAge[13] = 3.38e-2; // 60–64
  ProbBirthAge[14] = 2.53e-2; // 65–69
  ProbBirthAge[15] = 1.84e-2; // 70–74
  ProbBirthAge[16] = 1.40e-2; // 75–79
  ProbBirthAge[17] = 1.38e-2; // 80–84
  ProbBirthAge[18] = 0.02e-2; // 85–89
  ProbBirthAge[19] = 0.01e-2; // 90+

  SumProbBirthAge[0]  = ProbBirthAge[1];
  SumProbBirthAge[1]  = SumProbBirthAge[0]  + ProbBirthAge[2];
  SumProbBirthAge[2]  = SumProbBirthAge[1]  + ProbBirthAge[3];
  SumProbBirthAge[3]  = SumProbBirthAge[2]  + ProbBirthAge[4];
  SumProbBirthAge[4]  = SumProbBirthAge[3]  + ProbBirthAge[5];
  SumProbBirthAge[5]  = SumProbBirthAge[4]  + ProbBirthAge[6];
  SumProbBirthAge[6]  = SumProbBirthAge[5]  + ProbBirthAge[7];
  SumProbBirthAge[7]  = SumProbBirthAge[6]  + ProbBirthAge[8];
  SumProbBirthAge[8]  = SumProbBirthAge[7]  + ProbBirthAge[9];
  SumProbBirthAge[9]  = SumProbBirthAge[8]  + ProbBirthAge[10];
  SumProbBirthAge[10] = SumProbBirthAge[9]  + ProbBirthAge[11];
  SumProbBirthAge[11] = SumProbBirthAge[10] + ProbBirthAge[12];
  SumProbBirthAge[12] = SumProbBirthAge[11] + ProbBirthAge[13];
  SumProbBirthAge[13] = SumProbBirthAge[12] + ProbBirthAge[14];
  SumProbBirthAge[14] = SumProbBirthAge[13] + ProbBirthAge[15];
  SumProbBirthAge[15] = SumProbBirthAge[14] + ProbBirthAge[16];
  SumProbBirthAge[16] = SumProbBirthAge[15] + ProbBirthAge[17];
  SumProbBirthAge[17] = SumProbBirthAge[16] + ProbBirthAge[18];
  SumProbBirthAge[18] = SumProbBirthAge[17] + ProbBirthAge[19];

  AgeMin[0] = 0;
  AgeMax[0] = 4;

  AgeMin[1] = 5;
  AgeMax[1] = 9;

  AgeMin[2] = 10;
  AgeMax[2] = 14;

  AgeMin[3] = 15;
  AgeMax[3] = 19;

  AgeMin[4] = 20;
  AgeMax[4] = 24;

  AgeMin[5] = 25;
  AgeMax[5] = 29;

  AgeMin[6] = 30;
  AgeMax[6] = 34;

  AgeMin[7] = 35;
  AgeMax[7] = 39;

  AgeMin[8] = 40;
  AgeMax[8] = 44;

  AgeMin[9] = 45;
  AgeMax[9] = 49;

  AgeMin[10] = 50;
  AgeMax[10] = 54;

  AgeMin[11] = 55;
  AgeMax[11] = 59;

  AgeMin[12] = 60;
  AgeMax[12] = 64;

  AgeMin[13] = 65;
  AgeMax[13] = 69;

  AgeMin[14] = 70;
  AgeMax[14] = 74;

  AgeMin[15] = 75;
  AgeMax[15] = 79;

  AgeMin[16] = 80;
  AgeMax[16] = 84;

  AgeMin[17] = 85;
  AgeMax[17] = 89;

  AgeMin[18] = 90;
  AgeMax[18] = 100;
}
