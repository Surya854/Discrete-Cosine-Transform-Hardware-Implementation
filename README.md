# Discrete-Cosine-Transform-Hardware-Implementation
We were in a challenge to design the Hardware implementation of  16-Point 1-D Fast Discrete Cosine Transform 
Introduction:
DCT (Discrete Cosine Transform) is a popular tool used in image (JPEG), video (H.264) and audio 
(MP3) compression pipelines like JPEG, H.264, etc. The complexity and nature of calculations in 
the algorithm has lead to various works in finding efficient and optimized Hardware 
implementation of the algorithm
<img width="2048" height="1306" alt="image" src="https://github.com/user-attachments/assets/d6a9863a-94db-4412-92d7-245a0200ada2" />

The DCT Python code output is:
<img width="2135" height="90" alt="image" src="https://github.com/user-attachments/assets/e0da4ee4-f3e5-4555-9a5d-c754bef0c7c3" />

Our Verilog Implementation: 

The final output: Real_out_A and real_out_B are in the order given in the output stack above

<img width="2043" height="608" alt="image" src="https://github.com/user-attachments/assets/eb06d719-2b9d-4f91-8582-9f0998107c77" />

The processing through the compute stages:
<img width="2122" height="644" alt="image" src="https://github.com/user-attachments/assets/9b552aaf-20d2-4ccb-aca6-9769d86b3926" />
