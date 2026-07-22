function calculateBMI() {
  const heightCm = parseFloat(document.getElementById("height").value);
  const weightKg = parseFloat(document.getElementById("weight").value);
  const resultEl = document.getElementById("result");

  if (!heightCm || !weightKg || heightCm <= 0 || weightKg <= 0) {
    resultEl.textContent = "Please enter valid height and weight.";
    resultEl.style.color = "#c0392b";
    return;
  }

  const heightM = heightCm / 100;
  const bmi = weightKg / (heightM * heightM);
  const bmiRounded = bmi.toFixed(1);

  let category;
  let color;

  if (bmi < 18.5) {
    category = "Underweight";
    color = "#2980b9";
  } else if (bmi < 25) {
    category = "Normal weight";
    color = "#27ae60";
  } else if (bmi < 30) {
    category = "Overweight";
    color = "#f39c12";
  } else {
    category = "Obese";
    color = "#c0392b";
  }

  resultEl.textContent = `Your BMI is ${bmiRounded} (${category})`;
  resultEl.style.color = color;
}